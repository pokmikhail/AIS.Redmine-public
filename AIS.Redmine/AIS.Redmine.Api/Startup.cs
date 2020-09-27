using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using AIS.Redmine.Api.Models;
using AIS.Redmine.Api.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;

namespace AIS.Redmine.Api
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();

            ConfigureSwagger(services);

            ConfigureDB(services);

            // can't use DB as singletone, EF is single-threaded, https://docs.microsoft.com/en-us/ef/core/miscellaneous/configuring-dbcontext#avoiding-dbcontext-threading-issues
            services.AddScoped(typeof(IConfigurationService), typeof(DbConfigurationService));
            services.AddScoped(typeof(RedmineXmlImporter), typeof(RedmineXmlImporter));
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ILogger<Startup> logger)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                logger.LogInformation("app starting in development mode...");
            }
            else
            {
                app.UseExceptionHandler("/error");
                logger.LogInformation("app starting in production mode...");
            }

            app.UseSwagger();

            app.UseSwaggerUI(c=>
            {
                c.SwaggerEndpoint("./v1/swagger.json", "AIS.Redmine API v1");
            });

            app.UseHttpsRedirection();

            app.UseRouting();

            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });

            logger.LogInformation("app started");
        }

        public void ConfigureSwagger(IServiceCollection services)
        {
            // Register the Swagger generator, defining 1 or more Swagger documents
            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo
                {
                    Version = "v1",
                    Title = "AIS.Redmine API",
                    Description = "Our little Redmine helper.",
                    Contact = new OpenApiContact
                    {
                        Name = "Михаил Поковба",
                        Email = string.Empty
                    },
                });

                // Set the comments path for the Swagger JSON and UI.
                var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
                var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
                c.IncludeXmlComments(xmlPath);
            });
        }

        public void ConfigureDB(IServiceCollection services)
        {
            services.AddDbContext<DB>(
                options => options.UseSqlServer(Configuration.GetConnectionString("DB"))
                );
            ;
        }
    }
}
