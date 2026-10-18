{
  _config+:: {
    nameOverride: '',
    fullnameOverride: '',

    image: {
      repository: 'nginx',
      pullPolicy: 'IfNotPresent',
      tag: '',
    },
    imagePullSecrets: [],

    service: {
      type: 'ClusterIP',
      port: 80,
    },

    serviceAccount: {
      create: true,
      automount: true,
      annotations: {},
      name: '',
    },

    ingress: {
      enabled: false,
      className: '',
      annotations: {},
      hosts: [{
        host: 'chart-example.local',
        paths: [{
          path: '/',
          pathType: 'ImplementationSpecific',
        }],
      }],
      tls: [],
    },

    httpRoute: {
      enabled: false,
      annotations: {},
      parentRefs: [{
        name: 'gateway',
        sectionName: 'http',
      }],
      hostnames: ['chart-example.local'],
      rules: [{
        matches: [{
          path: {
            type: 'PathPrefix',
            value: '/headers',
          },
        }],
      }],
    },

    autoscaling: {
      enabled: false,
      minReplicas: 1,
      maxReplicas: 100,
      targetCPUUtilizationPercentage: 80,
      targetMemoryUtilizationPercentage: null,
    },

    replicaCount: 1,
    podAnnotations: {},
    podLabels: {},
    podSecurityContext: {},
    securityContext: {},
    resources: {},
    volumes: [],
    volumeMounts: [],
    nodeSelector: {},
    tolerations: [],
    affinity: {},

    livenessProbe: {
      httpGet: { path: '/', port: 'http' },
    },
    readinessProbe: {
      httpGet: { path: '/', port: 'http' },
    },
  },
}
