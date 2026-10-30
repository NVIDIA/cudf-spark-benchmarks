
WITH SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND 
        l.l_shipdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (ORDER BY sos.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierOrderStats sos ON s.s_suppkey = sos.s_suppkey
    WHERE 
        sos.total_sales > 10000
),
DistinctCustomers AS (
    SELECT 
        DISTINCT c.c_custkey, 
        c.c_name, 
        c.c_nationkey,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.sales_rank,
    COUNT(DISTINCT dc.c_custkey) AS distinct_customer_count,
    SUM(COALESCE(dc.c_acctbal, 0)) AS total_account_balance
FROM 
    TopSuppliers ts
LEFT JOIN 
    DistinctCustomers dc ON ts.s_suppkey = dc.c_nationkey
GROUP BY 
    ts.s_suppkey, 
    ts.s_name, 
    ts.sales_rank
HAVING 
    COUNT(DISTINCT dc.c_custkey) > 5
ORDER BY 
    total_account_balance DESC, 
    ts.sales_rank;
