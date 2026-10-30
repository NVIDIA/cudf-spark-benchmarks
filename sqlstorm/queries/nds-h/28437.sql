WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        p.p_name,
        p.p_brand,
        p.p_type
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    r.c_mktsegment,
    COALESCE(sp.p_name, 'Unknown') AS part_name,
    COALESCE(sp.s_name, 'Unknown Supplier') AS supplier_name,
    od.total_revenue,
    CASE 
        WHEN r.rank <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierParts sp ON r.o_orderkey = sp.ps_partkey
LEFT JOIN 
    OrderDetails od ON r.o_orderkey = od.l_orderkey
WHERE 
    r.o_orderdate >= '1997-01-01' AND 
    r.o_orderdate < '1997-12-31'
ORDER BY 
    r.o_orderdate DESC, 
    total_revenue DESC;