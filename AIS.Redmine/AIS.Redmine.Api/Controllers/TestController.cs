using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AIS.Redmine.Api.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace AIS.Redmine.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TestController : ControllerBase
    {
        private readonly ILogger<TestController> _logger;
        private readonly IConfigurationService _config;

        public TestController(
            ILogger<TestController> logger,
            IConfigurationService configuration
            )
        {
            _logger = logger;
            _config = configuration;
        }

        /// <summary>
        /// Test method
        /// </summary>
        [HttpGet]
        public IEnumerable<string> Get()
        {
            List<string> result = new List<string>();

            var keys = new[]
            {
                "non-existing",
                "Redmine:Url",
                "Redmine:ApiKey"
            };

            foreach (var key in keys) {
                var val = _config.Get(key) ?? "[ not set ]";
                result.Add(key + ": " + val);
            }

            return result;
        }
    }
}