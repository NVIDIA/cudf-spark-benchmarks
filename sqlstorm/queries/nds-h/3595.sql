WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        s.s_name
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
    LEFT JOIN 
        supplier s ON sp.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice > 100)
)
SELECT 
    ro.c_name AS customer_name,
    ro.o_orderdate AS order_date,
    pd.p_name AS product_name,
    pd.p_retailprice AS retail_price,
    sp.total_available AS available_quantity,
    sp.avg_supply_cost AS average_supply_cost
FROM 
    RankedOrders ro
LEFT JOIN 
    lineitem li ON ro.o_orderkey = li.l_orderkey
LEFT JOIN 
    PartDetails pd ON li.l_partkey = pd.p_partkey
LEFT JOIN 
    SupplierParts sp ON pd.p_partkey = sp.ps_partkey
WHERE 
    ro.order_rank <= 5
    AND pd.p_retailprice IS NOT NULL
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_orderkey ASC;
