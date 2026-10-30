WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CUME_DIST() OVER (ORDER BY c.c_acctbal DESC) AS cust_dist
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    hc.c_custkey,
    hc.c_name,
    fo.o_orderkey,
    fo.total_value,
    COALESCE(rs.s_name, 'N/A') AS supplier_name,
    rs.s_acctbal,
    fo.item_count
FROM 
    HighValueCustomers hc
LEFT JOIN 
    FilteredOrders fo ON hc.c_custkey = fo.o_custkey
LEFT JOIN 
    RankedSuppliers rs ON hc.c_custkey = rs.s_suppkey AND rs.rn = 1
WHERE 
    hc.cust_dist < 0.1 OR fo.total_value IS NULL
ORDER BY 
    total_value DESC NULLS LAST;