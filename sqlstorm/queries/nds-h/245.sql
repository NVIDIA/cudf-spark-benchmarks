
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'BUILDING'
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        li.l_shipdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name, 
    ns.n_name, 
    ns.total_orders, 
    ns.order_count, 
    hs.c_name AS high_value_customer,
    hs.c_acctbal AS high_value_acctbal,
    rs.s_name AS top_supplier,
    rs.total_parts,
    rs.total_supplycost
FROM 
    region r
JOIN 
    NationSummary ns ON r.r_regionkey = ns.n_nationkey
LEFT JOIN 
    HighValueCustomers hs ON hs.rank = 1 
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1;
