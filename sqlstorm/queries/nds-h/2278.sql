WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        s.s_name
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    COALESCE(ps.ps_supplycost, 0) AS cost_per_part,
    cs.total_orders,
    cs.total_spent,
    CONCAT('Order ', r.o_orderkey, ' on ', r.o_orderdate) AS order_details 
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierParts ps ON r.o_orderkey = ps.ps_partkey
LEFT JOIN 
    CustomerSummary cs ON r.o_orderkey = cs.c_custkey
WHERE 
    (r.o_orderstatus = 'O' OR r.o_orderstatus = 'F')
    AND r.order_rank <= 5
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;