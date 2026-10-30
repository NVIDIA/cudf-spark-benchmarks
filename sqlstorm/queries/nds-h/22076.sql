
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn,
        o.o_custkey
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        p.p_mfgr,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_size, p.p_retailprice, p.p_mfgr, p.p_type
),
HighValueOrders AS (
    SELECT 
        r.r_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY 
        r.r_name
)
SELECT 
    pd.p_name,
    pd.p_size,
    pd.p_retailprice,
    sd.s_name,
    sd.total_available_qty,
    hvo.total_order_value,
    CASE 
        WHEN hvo.total_order_value IS NULL THEN 'No Orders'
        WHEN sd.total_available_qty < 1 THEN 'Out of Stock'
        ELSE 'Available'
    END AS availability_status
FROM 
    PartDetails pd
LEFT JOIN 
    SupplierDetails sd ON pd.supplier_count > 0
LEFT JOIN 
    HighValueOrders hvo ON hvo.r_name = (SELECT r_name FROM region WHERE r_regionkey = 1)
WHERE 
    pd.p_retailprice BETWEEN 100.00 AND 200.00
    AND pd.supplier_count > 1
ORDER BY 
    pd.p_retailprice DESC, hvo.total_order_value DESC
LIMIT 50;
