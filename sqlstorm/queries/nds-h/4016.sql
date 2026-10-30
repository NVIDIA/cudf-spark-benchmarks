
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank,
        ps.ps_suppkey
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey, c.c_name
),
RecentOrders AS (
    SELECT 
        o.o_custkey,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    rp.p_name,
    rp.p_brand,
    co.total_spent,
    ro.last_order_date,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    COALESCE(rp.ps_availqty, 0) AS available_quantity
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedParts rp ON s.s_suppkey = rp.ps_suppkey AND rp.rank = 1
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = s.s_suppkey
LEFT JOIN 
    RecentOrders ro ON ro.o_custkey = co.c_custkey
WHERE 
    rp.p_retailprice BETWEEN 100 AND 500
    AND (co.order_count > 5 OR ro.last_order_date >= DATE '1997-01-01')
ORDER BY 
    r.r_name, n.n_name, s.s_name, rp.p_brand;
