WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_avail_qty,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_acctbal, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS rnk
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 10000
),
SignificantOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING 
        o.o_totalprice > 5000
)
SELECT 
    r.s_name AS supplier_name,
    r.total_avail_qty,
    hv.c_name AS customer_name,
    so.o_orderkey,
    so.o_totalprice,
    so.line_item_count
FROM 
    RankedSuppliers r
JOIN 
    HighValueCustomers hv ON r.rnk = 1
JOIN 
    SignificantOrders so ON so.line_item_count > 10
WHERE 
    r.total_avail_qty > 100
ORDER BY 
    r.total_avail_qty DESC, hv.c_acctbal DESC;
