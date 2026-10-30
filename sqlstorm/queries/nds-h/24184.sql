WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance'
            WHEN s.s_acctbal > 50000 THEN 'High Balance'
            ELSE 'Low Balance'
        END AS balance_category
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 0
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_value,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
FilteredOrders AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        od.net_value,
        od.o_orderstatus
    FROM 
        OrderDetails od
    WHERE 
        od.net_value > (SELECT AVG(net_value) FROM OrderDetails)
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    rp.p_name,
    hp.s_name,
    CASE 
        WHEN hp.balance_category = 'High Balance' THEN 'Priority Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_type,
    fo.o_orderkey,
    fo.o_orderdate,
    fo.net_value,
    spc.part_count
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    HighValueSuppliers hp ON ps.ps_suppkey = hp.s_suppkey
INNER JOIN 
    FilteredOrders fo ON fo.net_value < rp.p_retailprice
CROSS JOIN 
    SupplierPartCounts spc
WHERE 
    rp.price_rank = 1
    AND rp.p_name IS NOT NULL
    AND (spc.part_count > 5 OR hp.s_suppkey IS NULL)
ORDER BY 
    fo.o_orderkey DESC, 
    rp.p_name;
