WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_retailprice > 100
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
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    s.p_name AS part_name,
    s.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.total_spent,
    ro.o_orderstatus,
    ro.o_orderdate,
    CASE 
        WHEN ro.o_orderstatus = 'O' THEN 'Open'
        WHEN ro.o_orderstatus = 'F' THEN 'Finished'
        ELSE 'Unknown'
    END AS order_status_desc
FROM 
    SupplierParts s
JOIN 
    CustomerOrders co ON s.ps_suppkey = co.c_custkey
FULL OUTER JOIN 
    RankedOrders ro ON co.order_count = ro.order_rank
WHERE 
    s.supplier_rank = 1
    AND (co.total_spent IS NULL OR co.total_spent > 500)
ORDER BY 
    s.p_name, co.total_spent DESC;