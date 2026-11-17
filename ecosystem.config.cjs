module.exports = {
  apps: [
    {
      name: 'aws-nest-cicd',
      script: 'dist/main.js',
      instances: 1,
      exec_mode: 'fork',
      env: { NODE_ENV: 'production' },
    },
  ],
};
