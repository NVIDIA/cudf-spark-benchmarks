WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        COALESCE(NULLIF(s.s_address, ''), 'No Address') AS s_address,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_address
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
HighValueOrders AS (
    SELECT 
        od.o_orderkey,
        od.o_totalprice,
        od.total_revenue,
        RANK() OVER (ORDER BY od.total_revenue DESC) AS order_rank
    FROM OrderDetails od
    WHERE od.total_revenue > 10000.00
)

SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_mfgr, 
    rp.p_brand, 
    rp.p_retailprice, 
    si.s_name AS supplier_name, 
    si.s_address AS supplier_address, 
    hvo.o_totalprice AS order_total_price,
    hvo.order_rank
FROM RankedParts rp
LEFT JOIN SupplierInfo si ON rp.p_partkey = si.s_nationkey  
LEFT JOIN HighValueOrders hvo ON si.s_suppkey = hvo.o_orderkey
WHERE 
    rp.price_rank <= 5 
    AND (si.total_supply_cost IS NULL OR si.total_supply_cost > 5000.00)
ORDER BY 
    rp.p_brand, 
    hvo.order_rank DESC NULLS LAST;