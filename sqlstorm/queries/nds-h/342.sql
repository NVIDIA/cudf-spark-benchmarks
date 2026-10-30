WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) as rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(MAX(supply.total_supply_cost), 0) AS max_supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierCosts supply ON p.p_partkey = supply.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    rd.o_orderkey,
    rd.o_orderdate,
    rd.o_totalprice,
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.max_supply_cost,
    CASE 
        WHEN pd.max_supply_cost IS NULL THEN 'NO SUPPLY'
        WHEN pd.max_supply_cost < 100 THEN 'LOW SUPPLY'
        ELSE 'HIGH SUPPLY' 
    END AS supply_status
FROM 
    RankedOrders rd
JOIN 
    lineitem li ON rd.o_orderkey = li.l_orderkey
JOIN 
    PartDetails pd ON li.l_partkey = pd.p_partkey
WHERE 
    rd.rn <= 10
ORDER BY 
    rd.o_orderdate DESC, 
    rd.o_totalprice DESC;