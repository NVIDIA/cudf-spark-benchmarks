WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name, p.p_brand
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 10000
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name, 
    co.total_spending, 
    rp.o_orderkey,
    rp.o_orderdate,
    sp.p_name,
    sp.total_availqty,
    sp.total_supplycost,
    CASE 
        WHEN co.total_spending IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status,
    NULLIF(sp.total_availqty, 0) AS adjusted_availqty
FROM 
    CustomerOrders co
LEFT JOIN 
    RankedOrders rp ON co.total_spending > 5000
LEFT JOIN 
    SupplierParts sp ON sp.total_availqty > 100
WHERE 
    rp.order_rank = 1
ORDER BY 
    co.total_spending DESC, rp.o_orderdate ASC;