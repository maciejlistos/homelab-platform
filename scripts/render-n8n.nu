# Render n8n from its Argo CD chart configuration.
# Run from the repository root.
def main [output: string] {
    let app = (open kubernetes/applications/n8n.yaml)

    let charts = (
        $app.spec.sources
        | where {|source| ($source.chart? | default "") == "n8n"}
    )

    if ($charts | length) != 1 {
        error make {msg: "Expected exactly one n8n chart source"}
    }

    let chart = ($charts | first)
    let config = $chart.helm
    let namespace = $app.spec.destination.namespace

    # Fail if new Helm overrides would otherwise be silently ignored.
    let unsupported = (
        $config
        | columns
        | where {|key| $key not-in ["releaseName" "valueFiles"]}
    )

    if ($unsupported | is-not-empty) {
        error make {
            msg: $"Extend the renderer for these Helm settings: ($unsupported | str join ', ')"
        }
    }

    let value_args = (
        $config.valueFiles
        | each {|file|
            if not ($file | str starts-with '$values/') {
                error make {msg: $"Unsupported values reference: ($file)"}
            }

            ["--values" ($file | str replace '$values/' '')]
        }
        | flatten
    )

    let reference = $"oci://($chart.repoURL)/($chart.chart)"

        let helm_args = [
        template
        $config.releaseName
        $reference
        --version
        $chart.targetRevision
        --namespace
        $namespace
        --kube-version
        "1.36.3"
        ...$value_args
    ]

    let rendered = (
        do { ^helm ...$helm_args } | complete
    )

    if $rendered.exit_code != 0 {
        print --stderr $rendered.stderr
        error make {msg: "Helm rendering failed"}
    }

    # Persist only Deployments, not rendered Secrets or other resources.
    let deployments = (
        $rendered.stdout
        | from yaml
        | where {|document|
            ($document.kind? | default "") == "Deployment"
        }
        | each {|deployment|
            $deployment
            | upsert metadata.namespace (
                $deployment.metadata.namespace? | default $namespace
            )
        }
    )

    if ($deployments | is-empty) {
        error make {msg: "No Deployments rendered; refusing an empty policy check"}
    }

    $deployments
    | each {|deployment| $deployment | to yaml}
    | str join "\n---\n"
    | save --force $output

    print $"Rendered ($deployments | length) Deployment\(s\) to ($output)"
}
