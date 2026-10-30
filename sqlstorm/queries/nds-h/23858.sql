WITH  RegionSales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
        AND l.l_returnflag = 'N'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        r_name,
        total_sales
    FROM 
        RegionSales
    WHERE 
        sales_rank <= 3
),
CustomerRankings AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS cust_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tr.r_name,
    COALESCE(cr.c_name, 'No Customers') AS customer_name,
    tr.total_sales,
    cr.total_spent
FROM 
    TopRegions tr
FULL OUTER JOIN 
    CustomerRankings cr ON tr.total_sales = cr.total_spent * 1.1
WHERE 
    (tr.total_sales IS NOT NULL OR cr.total_spent IS NOT NULL)
ORDER BY 
    tr.total_sales DESC, cr.total_spent DESC
LIMIT 10;
