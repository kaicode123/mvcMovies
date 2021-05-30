using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MvcMovie.Data;
using MvcMovie.Models;
using System.Net.Http;
using Newtonsoft.Json;
using System.Text;


namespace MvcMovie.Controllers
{
    public class MoviesController : Controller
    {
        private readonly MvcMovieContext _context;

        public MoviesController(MvcMovieContext context)
        {
            _context = context;
        }

        // GET: Movies
        public async Task<IActionResult> Index()
        {
            //  return View(await _context.Movie.ToListAsync());

            List<Movie> moviesList = new List<Movie>();
            using (var httpClient = new HttpClient())
            {
                using (var response = await httpClient.GetAsync("http://localhost:7777/api/Movies"))
                {
                    string apiResponse = await response.Content.ReadAsStringAsync();
                    moviesList = JsonConvert.DeserializeObject<List<Movie>>(apiResponse);
                }
            }
            return View(moviesList);
        }

        // GET: Movies/Details/5
        public async Task<IActionResult> Details(int? id)
        {
            /* if (id == null)
             {
                 return NotFound();
             }

             var movie = await _context.Movie
                 .FirstOrDefaultAsync(m => m.Id == id);
             if (movie == null)
             {
                 return NotFound();
             }

             return View(movie);
            */
          
            List<Movie> moviesList = new List<Movie>();
            Movie movienew = new Movie();

            using (var httpClient = new HttpClient())
            {
                using (var response = await httpClient.GetAsync("http://localhost:7777/api/Movies/" + id))
                {
                    string apiResponse = await response.Content.ReadAsStringAsync();
                  //  moviesList = JsonConvert.DeserializeObject<List<Movie>>(apiResponse);
                    movienew = JsonConvert.DeserializeObject<Movie>(apiResponse);
                
                }
            }
            return View(movienew);

        }

        // GET: Movies/Create
        public IActionResult Create()
        {
            return View();
        }

        // POST: Movies/Create
        // To protect from overposting attacks, enable the specific properties you want to bind to, for 
        // more details, see http://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create([Bind("Id,Title,ReleaseDate,Genre,Price")] Movie movie)
        {
            /*   if (ModelState.IsValid)
               {
                   _context.Add(movie);
                   await _context.SaveChangesAsync();
                   return RedirectToAction(nameof(Index));
               }
               return View(movie); */

            Movie movienew = new Movie();
            using (var httpClient = new HttpClient())
            {
                StringContent content = new StringContent(JsonConvert.SerializeObject(movie), Encoding.UTF8, "application/json");

                using (var response = await httpClient.PostAsync("http://localhost:7777/api/Movies/", content))
                {
                    string apiResponse = await response.Content.ReadAsStringAsync();
                    movienew = JsonConvert.DeserializeObject<Movie>(apiResponse);
                }
            }
            //  return View(movienew);
            return RedirectToAction(nameof(Index));
        }

        // GET: Movies/Edit/5
        public async Task<IActionResult> Edit(int? id)
        {
            /*   if (id == null)
               {
                   return NotFound();
               }

               var movie = await _context.Movie.FindAsync(id);
               if (movie == null)
               {
                   return NotFound();
               }
               return View(movie); */

            Movie movienew  = new Movie();
            using (var httpClient = new HttpClient())
            {
                using (var response = await httpClient.GetAsync("http://localhost:7777/api/Movies/" + id))
                {
                    string apiResponse = await response.Content.ReadAsStringAsync();
                    movienew = JsonConvert.DeserializeObject<Movie>(apiResponse);
                }
            }
            return View(movienew);
        }

        // POST: Movies/Edit/5
        // To protect from overposting attacks, enable the specific properties you want to bind to, for 
        // more details, see http://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, [Bind("Id,Title,ReleaseDate,Genre,Price")] Movie movie)
        {
            /*   if (id != movie.Id)
               {
                   return NotFound();
               }

               if (ModelState.IsValid)
               {
                   try
                   {
                       _context.Update(movie);
                       await _context.SaveChangesAsync();
                   }
                   catch (DbUpdateConcurrencyException)
                   {
                       if (!MovieExists(movie.Id))
                       {
                           return NotFound();
                       }
                       else
                       {
                           throw;
                       }
                   }
                   return RedirectToAction(nameof(Index));
               }
               return View(movie);*/
            Movie movienew = new Movie();
            using (var httpClient = new HttpClient())
            {
                /*var content = new MultipartFormDataContent();
                content.Add(new StringContent(movie.Id.ToString()), "Id");
                content.Add(new StringContent(movie.Title), "Title");
                content.Add(new StringContent(movie.ReleaseDate.ToString()), "ReleaseDate");
                content.Add(new StringContent(movie.Genre), "Genre");
                content.Add(new StringContent(movie.Price.ToString()), "Price");*/

                StringContent content = new StringContent(JsonConvert.SerializeObject(movie), Encoding.UTF8, "application/json");

                using (var response = await httpClient.PutAsync("http://localhost:7777/api/Movies/" +id ,content))
                {
                    string apiResponse = await response.Content.ReadAsStringAsync();
                    ViewBag.Result = "Success";
                    movienew = JsonConvert.DeserializeObject<Movie>(apiResponse);
                }
            }
            return RedirectToAction(nameof(Index));
        }

        // GET: Movies/Delete/5
        public async Task<IActionResult> Delete(int? id)
        {
            /*    if (id == null)
                {
                    return NotFound();
                }

                var movie = await _context.Movie
                    .FirstOrDefaultAsync(m => m.Id == id);
                if (movie == null)
                {
                    return NotFound();
                }

                return View(movie);
            */
            using (var httpClient = new HttpClient())
            {
                using (var response = await httpClient.DeleteAsync("http://localhost:7777/api/Movies/" + id))
                {
                    string apiResponse = await response.Content.ReadAsStringAsync();
                }
            }

            return RedirectToAction("Index");
        }

      /*  // POST: Movies/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var movie = await _context.Movie.FindAsync(id);
            _context.Movie.Remove(movie);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }*/

        private bool MovieExists(int id)
        {
            return _context.Movie.Any(e => e.Id == id);
        }
    }
}
