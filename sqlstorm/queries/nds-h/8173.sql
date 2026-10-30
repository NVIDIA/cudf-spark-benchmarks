WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        r.r_name
), SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), SalesRanking AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    sr.region_name, 
    sr.total_sales, 
    spr.s_name AS supplier_name, 
    spr.total_supply_cost,
    sr.sales_rank
FROM 
    SalesRanking sr
JOIN 
    SupplierPerformance spr ON sr.region_name = (SELECT r.r_name 
                                                  FROM region r 
                                                  JOIN nation n ON r.r_regionkey = n.n_regionkey 
                                                  JOIN customer c ON c.c_nationkey = n.n_nationkey 
                                                  JOIN orders o ON c.c_custkey = o.o_custkey 
                                                  JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
                                                  WHERE l.l_shipdate >= DATE '1997-01-01' 
                                                    AND l.l_shipdate < DATE '1997-12-31' 
                                                  GROUP BY r.r_name 
                                                  ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC 
                                                  LIMIT 1)
ORDER BY 
    sr.sales_rank;