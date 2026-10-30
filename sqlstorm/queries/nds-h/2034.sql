WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
TopSellingParts AS (
    SELECT 
        r.r_name,
        SUM(rs.total_sales) AS region_sales
    FROM 
        RankedSales rs
    LEFT JOIN 
        partsupp ps ON rs.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.sales_rank = 1
    GROUP BY 
        r.r_name
    HAVING 
        SUM(rs.total_sales) > 10000
)
SELECT 
    c.c_custkey,
    c.c_name,
    co.o_orderkey,
    co.o_orderdate,
    COALESCE(tp.region_sales, 0) AS total_sales_by_region,
    c.c_acctbal,
    CASE 
        WHEN c.c_acctbal IS NULL THEN 'Account balance unknown'
        ELSE CONCAT('Account balance is: $', c.c_acctbal)
    END AS acct_balance_message
FROM 
    customer c
JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    TopSellingParts tp ON TRUE 
WHERE 
    co.order_rank <= 5
ORDER BY 
    total_sales_by_region DESC, co.o_orderdate DESC
LIMIT 50;