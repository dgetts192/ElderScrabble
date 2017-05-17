using System;
using System.Collections.Generic;

namespace Scrabble.Models
{
    public partial class Telephone
    {
        public int Id { get; set; }
        public int MemberId { get; set; }
        public string Number { get; set; }

        public virtual Member Member { get; set; }
    }
}
