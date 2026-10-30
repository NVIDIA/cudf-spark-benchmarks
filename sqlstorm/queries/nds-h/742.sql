WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND o.o_totalprice > 1000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 100 AND s.s_comment IS NOT NULL
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        MAX(p.p_retailprice) AS max_price,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM 
        part p
    LEFT JOIN 
        SupplierParts ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    pd.p_partkey,
    pd.p_name,
    pd.max_price,
    pd.num_suppliers,
    CASE 
        WHEN pd.max_price > 200 THEN 'Expensive'
        WHEN pd.max_price IS NULL THEN 'No Price'
        ELSE 'Affordable'
    END AS price_category
FROM 
    RankedOrders ro
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
WHERE 
    pd.num_suppliers > 0 AND 
    l.l_returnflag = 'N'
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_orderkey ASC;
