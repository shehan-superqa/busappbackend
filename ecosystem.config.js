module.exports = {
  apps: [{
    name: 'bus-ticketing',
    script: './server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production'
    },
    error_file: '/var/log/bus-ticketing-error.log',
    out_file: '/var/log/bus-ticketing-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};

