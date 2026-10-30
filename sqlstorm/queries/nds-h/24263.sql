WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank_by_spending
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        CASE 
            WHEN AVG(ps.ps_availqty) IS NULL THEN 'No Availability'
            ELSE 'Availability Exists'
        END AS availability_status
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    c.c_name,
    COALESCE(pt.p_name, 'Unknown Part') AS part_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    c.total_spent,
    s.total_supply_cost,
    pt.p_retailprice,
    CASE 
        WHEN pt.p_comment LIKE '%special%' THEN 'Special Comment'
        ELSE NULL
    END AS special_status,
    CASE
        WHEN s.total_supply_cost > 1000.00 THEN 'High Cost Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_type
FROM 
    CustomerOrders c 
LEFT JOIN 
    RankedParts pt ON c.rank_by_spending BETWEEN 1 AND 10
LEFT JOIN 
    SupplierDetails s ON s.total_supply_cost = (
        SELECT MAX(total_supply_cost) 
        FROM SupplierDetails sd 
        WHERE sd.s_acctbal BETWEEN 500.00 AND 3000.00
    )
WHERE 
    c.total_spent IS NOT NULL
AND 
    s.availability_status = 'Availability Exists'
OR 
    s.s_name IS NULL
ORDER BY 
    c.total_spent DESC, pt.p_retailprice ASC;
