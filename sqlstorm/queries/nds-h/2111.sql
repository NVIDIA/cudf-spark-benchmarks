WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn,
        c.c_acctbal
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        COALESCE(hv.total_supply_cost, 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        HighValueParts hv ON p.p_partkey = hv.ps_partkey
),
FinalReport AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.c_name,
        pd.p_name,
        pd.total_supply_cost,
        ro.c_acctbal,
        CASE 
            WHEN pd.total_supply_cost > 5000 THEN 'High'
            WHEN pd.total_supply_cost BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS cost_category
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        PartDetails pd ON l.l_partkey = pd.p_partkey
    WHERE 
        ro.rn <= 5
)
SELECT 
    c.c_name,
    SUM(fr.total_supply_cost) AS total_supply,
    AVG(fr.c_acctbal) AS avg_acctbal,
    CASE 
        WHEN COUNT(fr.o_orderkey) > 10 THEN 'Frequent'
        ELSE 'Infrequent'
    END AS order_frequency
FROM 
    FinalReport fr
JOIN 
    customer c ON fr.c_name = c.c_name
GROUP BY 
    c.c_name
HAVING 
    SUM(fr.total_supply_cost) > 10000
ORDER BY 
    total_supply DESC;
