
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        p.p_brand
    FROM 
        partsupp ps
    INNER JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice BETWEEN 100 AND 500
),
NationCustomer AS (
    SELECT 
        n.n_nationkey,
        n.n_name AS nation_name,
        c.c_name AS customer_name,
        c.c_acctbal
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    WHERE 
        c.c_acctbal IS NOT NULL AND
        c.c_mktsegment = 'BUILDING'
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        AVG(lo.l_quantity) AS average_quantity,
        COUNT(lo.l_orderkey) AS line_count
    FROM 
        lineitem lo
    WHERE 
        lo.l_shipdate IS NOT NULL
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    n.nation_name,
    n.customer_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(od.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(sp.ps_availqty), 0) AS total_available_supply,
    ARRAY_AGG(DISTINCT sp.p_name || ' (' || sp.p_brand || ')') AS available_parts
FROM 
    NationCustomer n
LEFT JOIN 
    RankedOrders o ON n.n_nationkey = o.o_orderkey 
LEFT JOIN 
    OrderDetails od ON o.o_orderkey = od.l_orderkey
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey IN (SELECT ps_partkey FROM SupplierParts SP WHERE sp.ps_supplycost < (SELECT MAX(ps_supplycost) FROM SupplierParts) / 2
                                            AND sp.ps_suppkey = n.n_nationkey)
GROUP BY 
    n.nation_name, n.customer_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    total_revenue DESC
LIMIT 10;
