
WITH  SalesCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_total,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
RankedSales AS (
    SELECT 
        s.o_orderkey,
        s.sales_total,
        s.customer_count,
        RANK() OVER (ORDER BY s.sales_total DESC) AS sales_rank
    FROM 
        SalesCTE s
),
TopSales AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COALESCE(ps.ps_availqty, 0) AS available_quantity,
        ps.ps_supplycost
    FROM 
        orders o
    LEFT JOIN 
        partsupp ps ON o.o_orderkey = ps.ps_partkey
    WHERE 
        ps.ps_supplycost IS NOT NULL
)
SELECT 
    r.sales_rank,
    r.sales_total,
    r.customer_count,
    t.o_orderdate,
    DENSE_RANK() OVER (PARTITION BY t.o_orderdate ORDER BY r.sales_total DESC) AS daily_rank
FROM 
    RankedSales r
JOIN 
    TopSales t ON r.o_orderkey = t.o_orderkey
WHERE 
    t.available_quantity IS NOT NULL
    AND r.sales_rank <= 10
ORDER BY 
    r.sales_rank, t.o_orderdate;
