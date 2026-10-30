WITH SupplierPartCost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(o.o_orderkey) AS order_count,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
),
NationRegionSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
)
SELECT 
    sp.s_name,
    sp.p_name,
    sp.total_cost,
    cos.c_name,
    cos.total_revenue,
    nrs.n_name,
    nrs.r_name,
    nrs.customer_count,
    nrs.total_order_value
FROM 
    SupplierPartCost sp
JOIN 
    CustomerOrderSummary cos ON sp.s_suppkey = cos.c_custkey
JOIN 
    NationRegionSummary nrs ON cos.c_custkey = nrs.n_nationkey
ORDER BY 
    sp.total_cost DESC, cos.total_revenue DESC, nrs.total_order_value DESC
LIMIT 100;