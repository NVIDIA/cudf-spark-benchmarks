
WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
),
HighAvailability AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.total_available,
        rp.avg_supplycost,
        ROW_NUMBER() OVER (PARTITION BY rp.p_mfgr ORDER BY rp.total_available DESC) AS rank
    FROM 
        RankedProducts rp
    WHERE 
        rp.total_available > 100
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    ha.p_partkey,
    ha.p_name,
    ha.p_mfgr,
    ha.total_available,
    ha.avg_supplycost,
    co.c_custkey,
    co.c_name,
    co.total_spent
FROM 
    HighAvailability ha
JOIN 
    CustomerOrders co ON ha.avg_supplycost < (SELECT AVG(ha2.avg_supplycost) FROM HighAvailability ha2)
WHERE 
    ha.rank <= 5
ORDER BY 
    ha.total_available DESC, co.total_spent DESC;
