WITH  RegionalSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
        n.n_nationkey, n.n_name
),
SalesRank AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
QualifyingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    r.n_name AS nation,
    s.total_sales AS total_sales,
    c.c_name AS customer_name,
    COALESCE(c.total_spent, 0) AS customer_total_spent
FROM 
    SalesRank s
LEFT JOIN 
    QualifyingCustomers c ON c.total_spent > 0
JOIN 
    nation r ON r.n_nationkey = s.n_nationkey
WHERE 
    s.sales_rank <= 5
ORDER BY 
    s.total_sales DESC, r.n_name ASC;
