
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rank_price
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierAggregate AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        COALESCE(sa.total_supply_cost, 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierAggregate sa ON p.p_partkey = sa.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalResults AS (
    SELECT 
        h.p_partkey,
        h.p_name,
        h.p_mfgr,
        h.p_retailprice,
        COALESCE(co.order_count, 0) AS customer_order_count,
        COALESCE(co.total_spent, 0) AS customer_total_spent,
        (CASE 
            WHEN h.total_supply_cost > 10000 THEN 'High Supply Cost' 
            ELSE 'Normal Supply Cost' 
         END) AS supply_cost_category
    FROM 
        HighValueParts h
    LEFT JOIN 
        CustomerOrders co ON h.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 5 ORDER BY ps.ps_supplycost DESC LIMIT 1)
    ORDER BY 
        h.p_retailprice DESC
)
SELECT 
    fr.p_partkey,
    fr.p_name,
    fr.p_mfgr,
    fr.customer_order_count,
    fr.customer_total_spent,
    fr.supply_cost_category,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = fr.p_partkey AND l.l_returnflag = 'R' AND l.l_tax > 0) AS return_count
FROM 
    FinalResults fr
WHERE 
    fr.customer_order_count > 3 AND
    fr.supply_cost_category = 'High Supply Cost' AND
    (fr.customer_total_spent / NULLIF(fr.customer_order_count, 0)) > 500
ORDER BY 
    fr.customer_total_spent DESC;
