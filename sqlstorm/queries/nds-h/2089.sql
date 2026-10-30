WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
HighSupplyParts AS (
    SELECT 
        p_partkey,
        p_name,
        s_suppkey,
        s_name,
        ps_availqty,
        ps_supplycost
    FROM 
        PartSupplierDetails
    WHERE 
        rn = 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 500
),
FinalReport AS (
    SELECT 
        hsp.p_name,
        hsp.s_name,
        co.c_name,
        co.total_spent,
        COALESCE(co.o_orderstatus, 'N/A') AS order_status
    FROM 
        HighSupplyParts hsp
    LEFT JOIN 
        CustomerOrders co ON hsp.s_suppkey = co.o_orderkey
)
SELECT 
    p_name,
    s_name,
    c_name,
    total_spent,
    order_status,
    CASE 
        WHEN total_spent IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_summary
FROM 
    FinalReport
WHERE 
    total_spent > 0
ORDER BY 
    total_spent DESC
LIMIT 10;