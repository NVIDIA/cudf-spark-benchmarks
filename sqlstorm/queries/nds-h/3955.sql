
WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_name
),
TopSales AS (
    SELECT 
        nation_name,
        total_sales
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 3
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000 THEN 'High Value'
            WHEN c.c_acctbal IS NULL THEN 'Unknown'
            ELSE 'Regular'
        END AS customer_segment
    FROM 
        customer c
    WHERE 
        c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name IN (SELECT nation_name FROM TopSales))
)
SELECT 
    f.c_name,
    f.customer_segment,
    ts.total_sales
FROM 
    FilteredCustomers f
LEFT JOIN 
    (SELECT o.o_custkey 
     FROM orders o 
     WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 500 
     ORDER BY o.o_orderdate DESC 
     LIMIT 1) AS subquery ON f.c_custkey = subquery.o_custkey
LEFT JOIN 
    TopSales ts ON subquery.o_custkey IS NOT NULL
WHERE
    ts.total_sales IS NOT NULL
ORDER BY 
    ts.total_sales DESC, f.customer_segment;
