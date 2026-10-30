WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_supplycost < 100.00
),
CustomerWithHighBalance AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > 5000
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    r.o_orderkey,
    la.total_revenue,
    la.total_quantity,
    sp.p_name,
    sp.supplier_name,
    sp.ps_supplycost
FROM 
    CustomerWithHighBalance co
JOIN 
    RankedOrders r ON co.c_custkey = r.o_orderkey
JOIN 
    LineItemAggregates la ON r.o_orderkey = la.l_orderkey
JOIN 
    SupplierPartDetails sp ON sp.ps_partkey IN (
        SELECT ps_partkey FROM partsupp
        WHERE ps_supplycost < 50.00
    )
WHERE 
    r.order_rank <= 5
ORDER BY 
    co.c_acctbal DESC, la.total_revenue DESC;