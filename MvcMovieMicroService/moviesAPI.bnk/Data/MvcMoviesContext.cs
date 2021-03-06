using Microsoft.EntityFrameworkCore;
using moviesAPI.Models;


namespace moviesAPI.Data
{
    public class MvcMovieContext : DbContext
    {
        public MvcMovieContext(DbContextOptions options)
            : base(options)
        {
        }

        public DbSet <Movies> Movies { get; set; }
    }
}