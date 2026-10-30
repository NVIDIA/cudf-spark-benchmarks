WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
SupplierAndParts AS (
    SELECT 
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        AVG(cp.total_spent) AS avg_spent_per_customer,
        SUM(SP.ps_availqty * SP.ps_supplycost) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        CustomerOrders cp ON n.n_nationkey = cp.c_custkey
    LEFT JOIN 
        SupplierAndParts SP ON SP.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 500)
    GROUP BY 
        r.r_name
)
SELECT 
    fr.r_name,
    fr.nation_count,
    fr.avg_spent_per_customer,
    CASE 
        WHEN fr.total_supply_cost IS NULL THEN 'No Supply'
        ELSE 'Has Supply'
    END AS supply_status
FROM 
    FinalReport fr
WHERE 
    fr.nation_count > 2
ORDER BY 
    fr.avg_spent_per_customer DESC, fr.r_name;