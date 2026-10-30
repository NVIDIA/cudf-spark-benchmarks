
WITH  RegionSales AS (
    SELECT 
        r.r_name AS region_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
),
CustomerRank AS (
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
    rs.region_name,
    cr.c_name,
    cr.total_spent,
    CASE 
        WHEN cr.total_spent > 1000 THEN 'High Spender'
        WHEN cr.total_spent BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    RegionSales rs
FULL OUTER JOIN 
    CustomerRank cr ON rs.region_name IS NOT NULL AND cr.total_spent IS NOT NULL
WHERE 
    rs.sales_rank <= 5 OR cr.cust_rank <= 5
ORDER BY 
    rs.total_sales DESC, cr.total_spent DESC;
