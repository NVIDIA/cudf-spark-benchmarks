WITH RankedSales AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate = (
            SELECT MAX(l2.l_shipdate) 
            FROM lineitem l2 
            WHERE l2.l_shipdate <= cast('1998-10-01' as date)
        )
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_suppkey
),
SupplierDetails AS (
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
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS acct_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) 
            FROM customer c2
        )
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.total_sales) AS total_order_sales,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    AVG(CASE WHEN c.c_custkey IS NULL THEN 0 ELSE c.c_acctbal END) AS avg_customer_balance,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS order_status
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    RankedSales l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    HighValueCustomers c ON o.o_custkey = c.c_custkey
WHERE 
    (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
    AND (ps.ps_availqty > 0 OR ps.ps_availqty IS NULL)
GROUP BY 
    r.r_name
ORDER BY 
    total_order_sales DESC
LIMIT 10;