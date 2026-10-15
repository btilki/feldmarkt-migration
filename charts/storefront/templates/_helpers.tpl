{{- define "storefront.name" -}}
storefront
{{- end -}}

{{- define "storefront.image" -}}
{{- $digest := .Values.image.digest -}}
{{- if not (regexMatch "^sha256:[0-9a-f]{64}$" $digest) -}}
{{- fail "image.digest must be a sha256 pin" -}}
{{- end -}}
{{- printf "%s@%s" .Values.image.repository $digest -}}
{{- end -}}
