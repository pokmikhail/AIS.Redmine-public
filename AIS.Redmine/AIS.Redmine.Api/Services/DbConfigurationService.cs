using AIS.Redmine.Models;
using AIS.Redmine.Api.Models;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AIS.Redmine.Api.Services
{
    public class DbConfigurationService : IConfigurationService
    {
        private readonly DB _db;

        private static ConcurrentDictionary<string, string> _data;
        private readonly object _lock = new object();

        public DbConfigurationService(DB db)
        {
            // init DB
            _db = db;

            _data = new ConcurrentDictionary<string, string>();
        }

        public string Get(string paramName)
        {
            Init();
            
            if (!_data.ContainsKey(paramName))
                throw new IndexOutOfRangeException($"No key with code '{paramName}'. Can't get value.");

            return _data[paramName];
        }

        public DateTimeOffset? GetDateTimeOffset(string paramName)
        {
            var value = Get(paramName);

            if (string.IsNullOrEmpty(value))
                return null;

            DateTimeOffset result = default;
            var ok = DateTimeOffset.TryParse(
                value,
                System.Globalization.DateTimeFormatInfo.InvariantInfo,
                System.Globalization.DateTimeStyles.AssumeUniversal,
                out result
                );

            if (!ok)
                return null;

            return result;
        }

        public async Task<bool> SetAndSaveAsync(string paramName, string value)
        {
            Init();

            if (!_data.ContainsKey(paramName))
                throw new IndexOutOfRangeException($"No key with code '{paramName}'. Can't set value.");

            _data[paramName] = value;

            var item = _db.Configuration.FirstOrDefault(d => d.Code == paramName);
            item.Value = value;
            item.Updated = DateTimeOffset.Now;
            await _db.SaveChangesAsync();

            return true;
        }

        public async Task<bool> SetAndSaveAsync(string paramName, DateTimeOffset? value)
        {
            string stringValue = null;
            if (value.HasValue)
                stringValue = value.Value.ToString(System.Globalization.DateTimeFormatInfo.InvariantInfo.UniversalSortableDateTimePattern);

            return await SetAndSaveAsync(paramName, stringValue);
        }

        private void Init()
        {
            if (!_data.IsEmpty)
                return;

            // read config from DB
            lock (_lock)
            {
                var dict = _db.Configuration.ToDictionary(d => d.Code,d => d.Value);
                foreach(var item in dict)
                {
                    _data[item.Key] = item.Value;
                }
            }
        }

        public void Reset()
        {
            _data.Clear();
        }
    }
}
