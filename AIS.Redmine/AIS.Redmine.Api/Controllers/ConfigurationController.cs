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
    [Produces("application/json")]
    public class ConfigurationController : ControllerBase
    {
        private readonly ILogger<TestController> _logger;
        private readonly IConfigurationService _config;
        private readonly DB _db;

        public ConfigurationController(
            ILogger<TestController> logger,
            IConfigurationService configuration,
            DB db
            )
        {
            _logger = logger;
            _config = configuration;
            _db = db;
        }

        [HttpGet]
        public ActionResult<List<ConfigItem>> Get()
        {
            var list =
                from d in _db.Configuration
                orderby d.Code
                select new ConfigItem
                {
                    Code = d.Code,
                    Name = d.Name,
                    Desctription = d.Description,
                    Value = d.Value
                };

            var result = list.ToList();

            return result;
        }

        [HttpGet("{parameterName}")]
        public ActionResult<ConfigItem> Get(string parameterName)
        {
            var item = _db.Configuration.FirstOrDefault(d => d.Code == parameterName);

            if (item == null)
                throw new ApiException("Nothing found.");

            var result = new ConfigItem
            {
                Code = item.Code,
                Name = item.Name,
                Desctription = item.Description,
                Value = item.Value
            };

            return result;
        }

        [HttpPost("{parameterName}")]
        public async Task<ActionResult> Set(string parameterName, string value)
        {
            var item = _db.Configuration.FirstOrDefault(d => d.Code == parameterName);

            if (item == null)
                throw new ApiException("Nothing found.");

            item.Value = value;

            await _db.SaveChangesAsync();

            _config.Reset();

            return Ok();
        }
    }
}