
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(COUNT(DISTINCT ps.ps_partkey), 0) AS supply_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey
) 
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    s.s_name AS supplier_name,
    cu.total_spent,
    cu.total_orders,
    CASE 
        WHEN r.o_orderstatus = 'O' THEN 'Open'
        WHEN r.o_orderstatus = 'F' THEN 'Filled'
        ELSE 'Unknown'
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY r.o_orderstatus ORDER BY r.o_totalprice DESC) AS order_position
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierInfo s ON r.o_orderkey = s.s_suppkey
LEFT JOIN 
    CustomerSummary cu ON r.o_orderkey = cu.c_custkey
WHERE 
    r.order_rank <= 10 AND 
    (s.s_acctbal IS NULL OR s.s_acctbal > 5000)
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
