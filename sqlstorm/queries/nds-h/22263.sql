WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= (cast('1998-10-01' as date) - INTERVAL '1 year')
    GROUP BY 
        o.o_orderkey
),
EligibleSupplies AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty IS NOT NULL AND ps.ps_availqty > 0
),
SufficientSupply AS (
    SELECT 
        f.o_orderkey,
        COUNT(e.ps_partkey) AS available_parts
    FROM 
        FilteredOrders f
    LEFT JOIN 
        EligibleSupplies e ON f.o_orderkey = e.ps_partkey
    GROUP BY 
        f.o_orderkey
    HAVING 
        COUNT(e.ps_partkey) >= 5
)
SELECT 
    r.s_suppkey,
    r.s_name,
    COALESCE(ss.available_parts, 0) AS order_counts,
    CONCAT('Supplier ', r.s_name, ' - ', r.s_acctbal) AS supplier_info
FROM 
    RankedSuppliers r
LEFT JOIN 
    SufficientSupply ss ON r.s_suppkey = ss.o_orderkey
WHERE 
    r.rank <= 3
ORDER BY 
    r.s_acctbal DESC, 
    order_counts DESC NULLS LAST;