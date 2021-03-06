using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using moviesAPI.Data;
using MySql.Data.MySqlClient;

namespace moviesAPI
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public async void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();
            services.AddDbContext<MvcMovieContext>(options => options.UseMySql(Configuration.GetConnectionString("MvcMovieContext")));

           // var sqlServerTokenProvider = new AzureServiceTokenProvider();
           // var SqlAccessToken = await sqlServerTokenProvider.GetAccessTokenAsync("https://ossrdbms-aad.database.windows.net").ConfigureAwait(false);
           // string connectionString = "mysqlxxb.mysql.database.azure.com; Port = 3306; Database = movies; Uid = myuser@mysqlxxb; Pwd = " + SqlAccessToken + "; SslMode = Preferred;";


            //var kvUri = "https://keyvaultaksb.vault.azure.net/";
            //var client = new SecretClient(new Uri(kvUri), new DefaultAzureCredential());
            //KeyVaultSecret secret = client.GetSecret("connectionString");

            // services.AddDbContext<MvcMovieContext>(options => options.UseMySql(secret.Value));     
            services.AddDbContext<MvcMovieContext>(options => options.UseMySql(connectionString));


        }

         
        
    

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        /*
         *The DefaultAzureCredential is very similar to the AzureServiceTokenProvider class 
         *as part of the Microsoft.Azure.Services.AppAuthentication. The DefaultAzureCredential gets 
         *the token based on the environment the application is running. The following credential types 
         *if enabled will be tried, in order - EnvironmentCredential, ManagedIdentityCredential, SharedTokenCacheCredential,
         */

       

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }


            app.UseCors(builder =>
            {
                builder
                .AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader();
            });

            app.UseHttpsRedirection();

            app.UseRouting();

            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}
