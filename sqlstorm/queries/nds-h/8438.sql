WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_comment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
),
LineItemSummary AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        AVG(li.l_quantity) AS avg_quantity,
        COUNT(DISTINCT li.l_suppkey) AS unique_suppliers
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate >= '1996-01-01' AND li.l_shipdate < '1997-01-01'
    GROUP BY 
        li.l_orderkey
)
SELECT 
    cp.c_custkey,
    cp.c_name,
    sp.s_suppkey,
    sp.s_name,
    sp.p_name,
    sp.p_brand,
    sp.p_retailprice,
    l.total_revenue,
    l.avg_quantity,
    l.unique_suppliers
FROM 
    CustomerOrderDetails cp
JOIN 
    LineItemSummary l ON cp.o_orderkey = l.l_orderkey
JOIN 
    SupplierPartDetails sp ON l.l_orderkey = sp.s_suppkey
WHERE 
    sp.ps_availqty > 1000
ORDER BY 
    cp.c_acctbal DESC, l.total_revenue DESC
LIMIT 50;