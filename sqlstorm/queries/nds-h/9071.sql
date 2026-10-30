WITH RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * l.l_quantity) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate <= DATE '1996-12-31' AND 
        l.l_shipmode = 'AIR'
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    nation,
    COUNT(s_suppkey) AS supplier_count,
    MAX(total_supply_cost) AS highest_supply_cost,
    MIN(total_supply_cost) AS lowest_supply_cost,
    AVG(total_supply_cost) AS average_supply_cost
FROM 
    RankedSales
WHERE 
    rank <= 10
GROUP BY 
    nation
ORDER BY 
    nation;