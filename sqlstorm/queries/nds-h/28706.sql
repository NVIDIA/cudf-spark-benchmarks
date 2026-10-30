WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability: ', CAST(ps.ps_availqty AS STRING), ' and supply cost: $', CAST(ps.ps_supplycost AS STRING)) AS supplier_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        CONCAT(c.c_name, ' placed order #', CAST(o.o_orderkey AS STRING), ' on ', CAST(o.o_orderdate AS STRING)) AS order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
DetailedInfo AS (
    SELECT 
        sp.supplier_info,
        co.order_info,
        ROW_NUMBER() OVER (PARTITION BY co.o_orderkey ORDER BY sp.ps_supplycost ASC) AS rn
    FROM 
        SupplierParts sp
    JOIN 
        CustomerOrders co ON sp.s_suppkey = co.c_custkey 
)
SELECT 
    supplier_info,
    order_info
FROM 
    DetailedInfo
WHERE 
    rn <= 5
ORDER BY 
    order_info, supplier_info;
