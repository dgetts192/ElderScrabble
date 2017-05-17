using System;
using System.Collections.Generic;

namespace Scrabble.Models
{
    public partial class Person
    {
        public int Id { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string DateOfBirth { get; set; }

        public virtual Member Member { get; set; }
    }
}
