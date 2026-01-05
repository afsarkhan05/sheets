-- big six
-- select from where group by having order by
-- distinct, count, limit
-- windows: row_number, rank, dense_rank
-- avg, min, max, lag, lead
-- cte vs sub query (common table expr is better clearer way if dealing with multi tables compare to sub query which will be complex)
-- left join - gives everything from left and (on joined from right) right join vice version , full inner join is excact join
-- full outer join is matching plus full from left and full from right table
-- self join - joining with itself
-- cte vs temp table (temp table are stored somewhere for sometime)
-- view vs table (view are better to expose your underling data with external team without providing exact column names or exposing all columns)

create schema sql_test;


CREATE TABLE baby_names (
    Gender VARCHAR(10),
    Name VARCHAR(50),
    Total INT
);

INSERT INTO baby_names (Gender, Name, Total) VALUES
('Girl', 'Ava', 95),
('Girl', 'Emma', 106),
('Boy', 'Ethan', 115),
('Girl', 'Isabella', 100),
('Boy', 'Jacob', 101),
('Boy', 'Liam', 84),
('Boy', 'Logan', 73),
('Boy', 'Noah', 120),
('Girl', 'Olivia', 100),
('Girl', 'Sophia', 88);


-- 1 order by table 
select * from baby_names bn order by total desc;

-- 2 add popularity column
select Gender , Name, Total,
	row_number() over(order by Total desc) as Popularity
from baby_names bn ;


-- 3 add popularity column with rank, row_number and rank_dense
select Gender , Name, Total,
	row_number() over(order by Total desc) as Popularity,
	rank() over(order by Total desc) as Popularity_r, -- rank but next skip over
	dense_rank() over(order by Total desc) as Popularity_d -- rank but wont skip over if multiple in same rank
from baby_names bn ;

-- 4 add popularity column within gender
select Gender , Name, Total,
	row_number() over(partition by Gender order by Total desc) as Popularity
from baby_names bn ;

-- 5 top 3 popular name within each gender
select * from 
(
select Gender , Name, Total,
	row_number() over(partition by Gender order by Total desc) as Popularity
from baby_names bn 
) pop
where pop.Popularity <=3;


with pop as (
select Gender , Name, Total,
	row_number() over(partition by Gender order by Total desc) as Popularity
from baby_names bn 
) 
select * from pop
where pop.Popularity <=3;




